mod redpanda;

use anyhow::Result;
use clap::{Parser, ValueEnum};
use chrono::Utc;
use dotenvy;
use env_logger::Env;
use log::info;
use rand::Rng;

use redpanda::config::KafkaConfig;
use redpanda::producer_async::RedpandaProducerAsync;
use redpanda::consumer_async::RedpandaConsumerAsync;

#[derive(ValueEnum, Clone, Debug)]
enum Mode {
    AsyncProducer,
    AsyncConsumer,
}

#[derive(Parser)]
#[command(name = "rust_redpanda", version, about = "redpanda demo in Rust with (Async)", long_about = None)]
struct Cli {
    #[arg(value_enum)]
    mode: Mode,
}

fn main() -> Result<()> {
    println!("📂 Current dir: {:?}", std::env::current_dir());

    // Load .env
    if dotenvy::dotenv().is_err() {
        panic!("⚠️ .env file not found");
    }

    // Init logger
    env_logger::Builder::from_env(Env::default().default_filter_or("info")).init();

    let cli = Cli::parse();
    let config = KafkaConfig::new();

    match cli.mode {
        Mode::AsyncProducer => run_async_producer(config)?,
        Mode::AsyncConsumer => run_async_consumer(config)?,
    }

    Ok(())
}

fn make_random_json() -> String {
    let temp = rand::thread_rng().gen_range(20.0..30.0);
    let humidity = rand::thread_rng().gen_range(50.0..80.0);
    let timestamp = Utc::now().to_rfc3339();

    format!(
        r#"{{"id":"A001","time":"{}","temp":{:.2},"humidity":{:.2}}}"#,
        timestamp, temp, humidity
    )
}

fn run_async_producer(config: KafkaConfig) -> Result<()> {
    info!("🚀 Running ASYNC producer (baseline test)...");
    let rt = tokio::runtime::Runtime::new()?;

    rt.block_on(async {
        let producer = RedpandaProducerAsync::new(&config)?;
        let msg = make_random_json();
        producer.send(&msg).await?;
        println!("Sent message...");
        Ok(())
    })
}


fn run_async_consumer(config: KafkaConfig) -> Result<()> {
    info!("📥 Running ASYNC consumer...");
    let rt = tokio::runtime::Runtime::new()?;

    rt.block_on(async {
        let consumer = RedpandaConsumerAsync::new(&config)?;
        consumer.run().await?;
        Ok(())
    })
}

