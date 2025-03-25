use actix_cors::Cors;
use actix_web::{get, middleware, web, App, HttpServer, Responder, Result};
use deadpool_postgres::{Config, GenericClient, ManagerConfig, RecyclingMethod};
use serde::{Deserialize, Serialize};
use server::Ship;
use std::error::Error;

#[derive(Debug, Deserialize, Serialize)]
struct SanitisedShip {
    ysws: String,
    code_url: String,
    demo_url: String,
    // screenshot_url: String,
    // description: String,
    hours: Option<f32>,
    country: String,
}

fn get_ships() -> Result<Vec<SanitisedShip>, Box<dyn Error>> {
    let f = std::fs::File::open("./ships.csv")?;
    let mut rdr = csv::Reader::from_reader(f);

    Ok(rdr
        .records()
        .map(|record| {
            let r = record.expect("a record");

            // print!("{}", r.get(1).unwrap().to_owned());

            return SanitisedShip {
                ysws: r.get(1).unwrap().to_owned(),
                code_url: r.get(11).unwrap().to_owned(),
                demo_url: r.get(10).unwrap().to_owned(),
                // screenshot_url: r.get(12).unwrap().to_owned(),
                // description: r.get(13).unwrap().to_owned(),
                hours: r.get(23).unwrap().to_owned().parse::<f32>().ok(),
                country: r.get(43).unwrap().to_owned(),
            };
        })
        .collect())
}

#[get("/")]
async fn index() -> Result<impl Responder> {
    Ok(web::Json(get_ships()?))
}

#[actix_web::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::init();

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
approved_at DATE
);",
        )
        .await
        .unwrap();

    let insert_ship_stmt = db_pool
        .get()
        .await?
        .prepare_cached("
            INSERT INTO ship (id, heard_through, github_username, country, hours, screenshot_url, code_url, demo_url, description, approved_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            ON CONFLICT (id) DO UPDATE SET
                heard_through = $2,
                github_username = $3,
                country = $4,
                hours = $5,
                screenshot_url = $6,
                code_url = $7,
                demo_url = $8,
                description = $9,
                approved_at = $10;")
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

    HttpServer::new(|| {
        let cors = Cors::permissive();

        App::new()
            .wrap(middleware::Compress::default())
            .wrap(cors)
            .service(index)
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await?;

    Ok(())
}
