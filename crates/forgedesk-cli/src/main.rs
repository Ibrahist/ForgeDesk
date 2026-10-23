use clap::{Parser, Subcommand};
use forgedesk_core::bridge::BridgeServer;
use forgedesk_core::config::AppConfig;
use std::net::SocketAddr;
use std::sync::Arc;

#[derive(Parser, Debug)]
#[command(name = "forgedesk-cli")]
#[command(author = "ForgeDesk Open Source Community")]
#[command(version = "0.1.0")]
#[command(about = "ForgeDesk Core CLI and Background Bridge Service", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Start the background IPC Bridge Server for Flutter UI
    Bridge {
        #[arg(short, long, default_value_t = 48123)]
        port: u16,
    },
    /// Run standalone host service (headless remote desktop host)
    Host {
        #[arg(long)]
        password: Option<String>,
    },
    /// Display local device ID and settings
    Status,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();
    let cli = Cli::parse();

    match cli.command.unwrap_or(Commands::Bridge { port: 48123 }) {
        Commands::Bridge { port } => {
            let bridge = Arc::new(BridgeServer::new());
            let status = bridge.get_status().await;

            println!("============================================================");
            println!("             FORGEDESK DESKTOP CORE DAEMON                  ");
            println!("============================================================");
            println!("  Device ID          : {}", status.my_id);
            println!("  Temporary Password : {}", status.temporary_password);
            println!("  Rendezvous Server  : {}", status.server_url);
            println!("  Bridge IPC Port    : ws://127.0.0.1:{}", port);
            println!("------------------------------------------------------------");
            println!("  Flutter GUI and remote clients can now connect.");
            println!("============================================================");

            let addr: SocketAddr = format!("127.0.0.1:{}", port).parse()?;
            bridge.run_server(addr).await?;
        }
        Commands::Host { password: _ } => {
            let bridge = Arc::new(BridgeServer::new());
            bridge.start_hosting().await;
            let status = bridge.get_status().await;

            println!("ForgeDesk Host active!");
            println!("Your ID: {}", status.my_id);
            println!("Password: {}", status.temporary_password);
            println!("Waiting for connections...");

            // Keep alive
            tokio::signal::ctrl_c().await?;
            println!("Host terminated.");
        }
        Commands::Status => {
            let config = AppConfig::load_or_create();
            println!("Device ID: {}", config.peer_id);
            println!("Rendezvous: {}", config.settings.rendezvous_server);
            println!("Relay: {}", config.settings.relay_server);
            println!("Self-hosted: {}", config.settings.is_self_hosted);
        }
    }

    Ok(())
}
