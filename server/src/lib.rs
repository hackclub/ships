use once_cell::sync::OnceCell;
use reqwest::header::{HeaderMap, HeaderValue};
use serde::Serialize;
use serde_json::json;
use time::{macros::format_description, Date};

fn embeddings_client() -> &'static reqwest::Client {
    static EMBEDDINGS_CLIENT: OnceCell<reqwest::Client> = OnceCell::new();
    EMBEDDINGS_CLIENT.get_or_init(|| {
        let client = reqwest::ClientBuilder::new();

        let bearer = format!(
            "Bearer {}",
            std::env::var("OPENAI_KEY").expect("an OPENAI_KEY env var")
        );
        let mut headers = HeaderMap::new();
        headers.append(
            reqwest::header::CONTENT_TYPE,
            HeaderValue::from_static("application/json"),
        );
        headers.append(
            reqwest::header::AUTHORIZATION,
            HeaderValue::from_str(&bearer).expect("a str headervalue"),
        );

        client.default_headers(headers).build().unwrap()
    })
}

#[derive(Debug, Serialize)]
pub struct Ship {
    pub id: String,
    pub heard_through: Option<String>,
    pub github_username: Option<String>,
    pub country: Option<String>,
    pub hours: Option<f64>,
    pub screenshot_url: Option<String>,
    pub code_url: Option<String>,
    pub demo_url: Option<String>,
    pub description: Option<String>,
    pub approved_at: Option<Date>,
    pub ysws: Option<String>,
}
impl Ship {
    pub async fn fetch_unified_page(
        cursor: &Option<String>,
    ) -> Option<(Vec<Self>, Option<String>)> {
        let cursor_url_param = match cursor {
            Some(c) => &format!("&offset={c}"),
            None => "",
        };
        let url = format!("https://api.airtable.com/v0/app3A5kJwYqxMLOgh/Approved%20Projects?view=Ben - All{cursor_url_param}");

        let res = reqwest::Client::new()
            .get(url)
            .bearer_auth(std::env::var("AIRTABLE_PAT").expect("an airtable PAT"))
            .send()
            .await
            .ok()?
            .json::<serde_json::Value>()
            .await
            .ok()?;

        let cursor = res
            .get("offset")
            .map(|a| a.as_str().map(|b| b.to_string()))
            .flatten();
        let records = res.get("records").map(|r| r.as_array()).flatten()?;

        let format = format_description!("[year]-[month]-[day]");

        Some((
            records
                .iter()
                .map(|t| {
                    let f = t
                        .get("fields")
                        .map(|f| f.as_object())
                        .flatten()
                        .expect("arstrs");

                    let mut ship = Ship {
                        id: Self::field(t.get("id")).expect("a record id"),
                        heard_through: Self::field(f.get("How did you hear about this?")),
                        github_username: Self::field(f.get("GitHub Username")),
                        country: t
                            .pointer("/fields/Hack Clubber–Geocoded Country/0")
                            .map(|a| a.as_str().map(|b| b.to_string()))
                            .flatten(),
                        hours: f.get("Hours Spent").map(|a| a.as_f64()).flatten(),
                        screenshot_url: t
                            .pointer("/fields/Screenshot/0/url")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string()),
                        code_url: Self::field(f.get("Code URL")),
                        demo_url: Self::field(f.get("Playable URL")),
                        description: Self::field(f.get("Description")),
                        approved_at: f
                            .get("Approved At")
                            .map(|a| a.as_str().map(|b| Date::parse(b, &format).ok()))
                            .flatten()
                            .flatten(),
                        ysws: t
                            .pointer("/fields/YSWS–Name/0")
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string()),
                    };

                    ship
                })
                .collect::<Vec<Ship>>(),
            cursor,
        ))
    }

    fn field(v: Option<&serde_json::Value>) -> Option<String> {
        v.map(|s| {
            s.as_str().map(
                |a| a.to_string().replace('\0', ""), // Somebody's description had a null byte 😭
            )
        })
        .flatten()
    }

    pub async fn embed_text(input: &str) -> Result<Vec<f32>, reqwest::Error> {
        static EMBEDDING_MODEL: &str = "text-embedding-3-small";

        Ok(embeddings_client()
            .post("https://api.openai.com/v1/embeddings")
            .json(&json!({ "input": input, "model": EMBEDDING_MODEL }))
            .send()
            .await?
            .json::<serde_json::Value>()
            .await?
            .pointer("/data/0/embedding")
            .unwrap()
            .as_array()
            .unwrap()
            .iter()
            .map(|v| v.as_f64().unwrap() as f32)
            .collect())
    }

    pub async fn embed(&self) -> Result<Option<Vec<f32>>, reqwest::Error> {
        if let Some(desc) = &self.description {
            Self::embed_text(desc).await.map(Some)
        } else {
            Ok(None)
        }
    }
}
