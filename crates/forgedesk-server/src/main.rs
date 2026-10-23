mod relay;
mod rendezvous;

use clap::Parser;
use relay::RelayServer;
use rendezvous::RendezvousServer;
use std::net::SocketAddr;

#[derive(Parser, Debug)]
#[command(name = "forgedesk-server")]
#[command(author = "ForgeDesk Open Source Community")]
#[command(version = "0.1.0")]
#[command(about = "Self-hosted Rendezvous and Relay Server for ForgeDesk", long_about = None)]
struct Args {
    /// Bind address for both services
    #[arg(short, long, default_value = "0.0.0.0")]
    bind: String,

    /// Port for Rendezvous & Signaling service
    #[arg(long, default_value_t = 21115)]
    rendezvous_port: u16,

    /// Port for Relay service
    #[arg(long, default_value_t = 21117)]
    relay_port: u16,

    /// Optional secret server key required by clients to connect
    #[arg(long)]
    server_key: Option<String>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();
    let args = Args::parse();

    let rendezvous_addr: SocketAddr = format!("{}:{}", args.bind, args.rendezvous_port).parse()?;
    let relay_addr: SocketAddr = format!("{}:{}", args.bind, args.relay_port).parse()?;

    println!("============================================================");
    println!("             FORGEDESK SELF-HOSTED SERVER                   ");
    println!("============================================================");
    println!("  Rendezvous / Signaling Service : ws://{}", rendezvous_addr);
    println!("  Relay Streaming Service        : ws://{}", relay_addr);
    if let Some(key) = &args.server_key {
        println!("  Server Key (Authentication)    : {}", key);
    } else {
        println!("  Server Key (Authentication)    : (Public / None required)");
    }
    println!("------------------------------------------------------------");
    println!("  Configure your ForgeDesk Client with:");
    println!("    * Rendezvous Server: {}:{}", args.bind, args.rendezvous_port);
    println!("    * Relay Server     : {}:{}", args.bind, args.relay_port);
    println!("============================================================");

    let rendezvous = RendezvousServer::new(args.server_key);
    let relay = RelayServer::new();

    let rendezvous_task = tokio::spawn(async move {
        if let Err(e) = rendezvous.run(rendezvous_addr).await {
            tracing::error!("Rendezvous service fatal error: {:?}", e);
        }
    });

    let relay_task = tokio::spawn(async move {
        if let Err(e) = relay.run(relay_addr).await {
            tracing::error!("Relay service fatal error: {:?}", e);
        }
    });

    tokio::select! {
        _ = rendezvous_task => {},
        _ = relay_task => {},
    }

    Ok(())
}
