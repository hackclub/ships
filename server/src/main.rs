use actix_cors::Cors;
use actix_web::{get, middleware, post, web, App, HttpResponse, HttpServer, Responder, Result};
use serde::{Deserialize, Serialize};
use std::{error::Error, io, process};

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

#[get("/ships")]
async fn ships() -> Result<impl Responder> {
    Ok(web::Json(get_ships()?))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        let cors = Cors::permissive();

        App::new()
            .wrap(middleware::Compress::default())
            .wrap(cors)
            .service(ships)
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
