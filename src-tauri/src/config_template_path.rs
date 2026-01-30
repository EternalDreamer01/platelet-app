use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ConfigTemplatePath {
    pub omnetpp_path: String,
    pub sumocfg_path: String,
    pub services_path: String,
}

impl Default for ConfigTemplatePath {
    fn default() -> Self {
        let tauri_home: std::string::String = std::env::var("PLATELET_TAURI_HOME")
			.expect("tauri_home is not set");
        Self {
            omnetpp_path: String::from(&format!("{}/assets/omnetpp.ini", tauri_home)),
            sumocfg_path: String::from(&format!("{}/assets/base.sumocfg", tauri_home)),
            services_path: String::from(&format!("{}/assets/services.xml", tauri_home)),
        }
    }
}
