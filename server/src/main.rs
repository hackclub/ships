use actix_cors::Cors;
use actix_web::{get, middleware, web, App, HttpServer, Responder, Result};
use deadpool_postgres::{Config, GenericClient, ManagerConfig, Pool, RecyclingMethod};
use serde::{Deserialize, Serialize};
use server::Ship;
use std::error::Error;

#[get("/")]
async fn index(data: web::Data<AppState>) -> Result<impl Responder, Box<dyn Error>> {
    let ships: Vec<Ship> = data
        .db_pool
        .get()
        .await?
        .query("SELECT * FROM ship ORDER BY approved_at asc;", &[])
        .await?
        .iter()
        .map(|row| Ship {
            id: row.get("id"),
            heard_through: row.get("heard_through"),
            github_username: row.get("github_username"),
            country: row.get("country"),
            hours: row.get("hours"),
            screenshot_url: row.get("screenshot_url"),
            code_url: row.get("code_url"),
            demo_url: row.get("demo_url"),
            description: row.get("description"),
            approved_at: row.get("approved_at"),
            ysws: row.get("ysws"),
        })
        .collect();

    Ok(web::Json(ships))
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
ysws TEXT
);",
        )
        .await
        .unwrap();

    let insert_ship_stmt = db_pool
        .get()
        .await?
        .prepare_cached("
            INSERT INTO ship (id, heard_through, github_username, country, hours, screenshot_url, code_url, demo_url, description, approved_at, ysws)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
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
                ysws = $11;")
        .await?;
    //#endregion

    let pool_item = db_pool.get().await?;
    tokio::task::spawn(async move {
        let mut cursor = None::<String>;

        loop {
            if let Some((ships, new_cursor)) = Ship::fetch_unified_page(&cursor).await {
                cursor = new_cursor;
                for ship in ships.iter() {
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
                            ],
                        )
                        .await
                        .expect("the query to execute");
                }
            }
            println!("Inserted");

            tokio::time::sleep(tokio::time::Duration::from_millis(1_000)).await;
        }
    });

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
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await?;

    Ok(())
}
