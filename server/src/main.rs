use actix_cors::Cors;
use actix_web::{get, middleware, web, App, HttpResponse, HttpServer, Responder, Result};
use deadpool_postgres::{Config, GenericClient, ManagerConfig, Pool, RecyclingMethod};
use serde::Deserialize;
use serde_json::json;
use server::Ship;
use std::error::Error;

// Cacheable ship info
#[get("/")]
async fn index(data: web::Data<AppState>) -> Result<HttpResponse, Box<dyn Error>> {
    let ships: Vec<serde_json::Value> = data
        .db_pool
        .get()
        .await?
        .query("SELECT id, heard_through, github_username, country, hours, code_url, demo_url, description, approved_at, ysws FROM ship ORDER BY approved_at asc;", &[])
        .await?
        .iter()
        .map(|row| {
            json!({
                "id": row.get::<&str, &str>("id"),
                "heard_through": row.get::<&str, Option<&str>>("heard_through"),
                "github_username": row.get::<&str, Option<&str>>("github_username"),
                "country": row.get::<&str, Option<&str>>("country"),
                "hours": row.get::<&str, Option<f64>>("hours"),
                "code_url": row.get::<&str, Option<&str>>("code_url"),
                "demo_url": row.get::<&str, Option<&str>>("demo_url"),
                "description": row.get::<&str, Option<&str>>("description"),
                "approved_at": row.get::<&str, Option<time::Date>>("approved_at"),
                "ysws": row.get::<&str, Option<&str>>("ysws")
            })
        })
        .collect();

    let json = serde_json::to_string(&ships).unwrap();

    let response = HttpResponse::Ok()
        .content_type("application/json")
        .append_header(("x-length", json.len().to_string())) // Content-Length doesn't set.
        .body(json);

    Ok(response)
}

// Separate endpoint for screenshots because they expire
#[get("/screenshots")]
async fn screenshots(data: web::Data<AppState>) -> Result<impl Responder, Box<dyn Error>> {
    let screenshot_urls: Vec<Option<String>> = data
        .db_pool
        .get()
        .await?
        .query(
            "SELECT screenshot_url FROM ship ORDER BY approved_at asc;",
            &[],
        )
        .await?
        .iter()
        .map(|row| row.get::<&str, Option<String>>("screenshot_url"))
        .collect();

    Ok(web::Json(screenshot_urls))
}

#[derive(Deserialize)]
struct SearchInfo {
    query: String,
}

#[get("/search")]
async fn search(
    data: web::Data<AppState>,
    info: web::Query<SearchInfo>,
) -> Result<impl Responder, Box<dyn Error>> {
    let embedding = Ship::embed_text(&info.query).await?;
    let embedding = pgvector::Vector::from(embedding);

    let row = data
        .db_pool
        .get()
        .await?
        .query_one(
            "SELECT * FROM ship where description is not null ORDER BY embedding <-> $1 LIMIT 1",
            &[&embedding],
        )
        .await?;

    Ok(row.get::<&str, String>("id"))
}

struct AppState {
    db_pool: Pool,
}

#[actix_web::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    //#region DB setup
    let mut db_cfg = Config::new();
    db_cfg.url = Some(std::env::var("DB_URL").expect("a Postgres URL").to_string());
    db_cfg.manager = Some(ManagerConfig {
        recycling_method: RecyclingMethod::Fast,
    });
    let db_pool = db_cfg
        .create_pool(
            Some(deadpool_postgres::Runtime::Tokio1),
            tokio_postgres::NoTls,
        )
        .unwrap();

    db_pool
        .get()
        .await
        .unwrap()
        .execute("CREATE EXTENSION IF NOT EXISTS vector;", &[])
        .await
        .unwrap();

    db_pool
        .get()
        .await
        .unwrap()
        .batch_execute(
            "CREATE TABLE IF NOT EXISTS ship (
    id TEXT PRIMARY KEY,
    heard_through TEXT,
    github_username TEXT,
    country TEXT,
    hours DOUBLE PRECISION,
    screenshot_url TEXT,
    code_url TEXT,
    demo_url TEXT,
    description TEXT,
    approved_at DATE,
    ysws TEXT,
    embedding VECTOR(1536)
);",
        )
        .await
        .unwrap();

    let insert_ship_stmt = db_pool
        .get()
        .await?
        .prepare_cached("
            INSERT INTO ship (id, heard_through, github_username, country, hours, screenshot_url, code_url, demo_url, description, approved_at, ysws, embedding)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            ON CONFLICT (id) DO UPDATE SET
                heard_through = $2,
                github_username = $3,
                country = $4,
                hours = $5,
                screenshot_url = $6,
                code_url = $7,
                demo_url = $8,
                description = $9,
                approved_at = $10,
                ysws = $11,
                embedding = $12;")
        .await?;
    //#endregion

    async fn get_db_ship_count(
        pool_item: &deadpool_postgres::Object,
    ) -> Result<usize, Box<dyn Error>> {
        let count =
            pool_item.query("SELECT COUNT(*) FROM ship;", &[]).await?[0].get::<&str, i64>("count");

        Ok(count as usize)
    }

    async fn update_github_description(ship_count: usize) -> Result<(), reqwest::Error> {
        use num_format::{Locale, ToFormattedString};

        let ship_count: String = ship_count.to_formatted_string(&Locale::en);

        let gh_client = reqwest::Client::new();

        println!(
            "{:?}",
            gh_client
                .patch("https://api.github.com/repos/hackclub/ships")
                .bearer_auth(std::env::var("GITHUB_PAT").expect("a GITHUB_PAT env var"))
                .header("X-GitHub-Api-Version", "2022-11-28")
                .header("User-Agent", "hackclub/ships-server")
                .header("Accept", "application/vnd.github+json")
                .json(&json!({ "description": format!("🚢 {ship_count} Ships, visualised") }))
                .send()
                .await
                .unwrap()
                .text()
                .await
                .unwrap()
        );

        Ok(())
    }

    let pool_item = db_pool.get().await?;
    tokio::task::spawn(async move {
        let mut cursor = None::<String>;

        loop {
            if let Some((ships, new_cursor)) = Ship::fetch_unified_page(&cursor).await {
                for ship in ships.iter() {
                    let vec = match ship.embed().await.unwrap() {
                        Some(v) => Some(pgvector::Vector::from(v)),
                        None => None,
                    };

                    pool_item
                        .query(
                            &insert_ship_stmt,
                            &[
                                &ship.id,
                                &ship.heard_through,
                                &ship.github_username,
                                &ship.country,
                                &ship.hours,
                                &ship.screenshot_url,
                                &ship.code_url,
                                &ship.demo_url,
                                &ship.description,
                                &ship.approved_at,
                                &ship.ysws,
                                &vec,
                            ],
                        )
                        .await
                        .expect("the prepared insert statement to execute");
                }

                cursor = if ships.len() < 100 {
                    let db_count = get_db_ship_count(&pool_item)
                        .await
                        .expect("the count statement to execute");
                    println!("Done. Go back to the start");
                    let _ = update_github_description(db_count).await;
                    None
                } else {
                    new_cursor
                };

                println!("Upserted {} ships", ships.len());
            }

            tokio::time::sleep(tokio::time::Duration::from_millis(1_000)).await;
        }
    });

    let port = std::env::var("DEPLOYMENT_PORT")
        .map(|i| {
            i.parse::<u16>()
                .expect("env var DEPLOYMENT_PORT should be an integer")
        })
        .unwrap_or(8080);

    HttpServer::new(move || {
        let cors = Cors::permissive();

        let app_state = AppState {
            db_pool: db_pool.clone(),
        };

        App::new()
            .wrap(middleware::Compress::default())
            .wrap(cors)
            .app_data(web::Data::new(app_state))
            .service(index)
            .service(screenshots)
            .service(search)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await?;

    Ok(())
}
