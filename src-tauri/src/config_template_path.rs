use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ConfigTemplatePath {
    pub omnetpp_path: String,
    pub sumocfg_path: String,
    pub services_path: String,
}

impl Default for ConfigTemplatePath {
    fn default() -> Self {
        let PLATELET_TAURI_HOME: std::string::String = std::env::var("PLATELET_TAURI_HOME")
			.expect("PLATELET_TAURI_HOME is not set");
        Self {
            omnetpp_path: String::from(&format!("{}/assets/omnetpp.ini", PLATELET_TAURI_HOME)),
            sumocfg_path: String::from(&format!("{}/assets/base.sumocfg", PLATELET_TAURI_HOME)),
            services_path: String::from(&format!("{}/assets/services.xml", PLATELET_TAURI_HOME)),
        }
    }
}
