use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ConfigTemplatePath {
    pub omnetpp_path: String,
    pub sumocfg_path: String,
    pub services_path: String,
}

impl Default for ConfigTemplatePath {
    fn default() -> Self {
        Self {
            omnetpp_path: String::from("./assets/omnetpp.ini"),
            sumocfg_path: String::from("./assets/base.sumocfg"),
            services_path: String::from("./assets/services.xml"),
        }
    }
}
