// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::{env::set_current_dir, path::Path, process::Command, sync::Mutex};

use misc::{create_folder_if_not_exist, create_menu_bar, create_menu_even_listener, create_new_project_window};
use once_cell::sync::OnceCell;
use project::Project;
use tauri::Manager;

mod artery_configuration_builder;
mod misc;
mod project;
mod security_configuration;
mod config_template_path;

static LOADED_PROJECT: OnceCell<Mutex<Project>> = OnceCell::new();
const PROJECT_BUILD: &str = "./build";

//TODO: move commands in dedicated file main is too long

#[tauri::command]
fn compile_artery() -> Result<(), String> {
    let loaded_project = match LOADED_PROJECT.get() {
        Some(loaded_project_mutex) => match loaded_project_mutex.lock() {
            Ok(loaded_project) => loaded_project,
            Err(e) => {
                return Err(format!(
                    "Can't lock loaded project mutex: {}",
                    e.to_string()
                ))
            }
        },
        None => return Err("Can't get loaded project".to_owned()),
    };
    let artery_path = loaded_project.artery_path.clone();
    set_current_dir(artery_path).map_err(|e| format!("Can't change directory to artery: {}", e))?;

    let build_path = Path::new(PROJECT_BUILD);

    create_folder_if_not_exist(build_path)
        .map_err(|e| format!("Can't create build directory: {}", e))?;

	println!("Project path: {}", loaded_project.project_name);
	println!("Artery path: {}", loaded_project.artery_path);
	println!("Build path: {}", build_path.display());

    Command::new("cmake")
        .args([
			"-S",
			&("./scenarios/".to_owned()+&loaded_project.project_name),
			"-B",
			PROJECT_BUILD,
			// &format!("-DCMAKE_MODULE_PATH={}", OMNETPP_HOME), //, ARTERY_HOME),
		])
        .spawn()
        .unwrap();
	
	let jobs = std::thread::available_parallelism()
		.map(|n| {
			let cpus = n.get();
			// take 2/3 of CPUs, at least 1
			((cpus * 2) / 3).max(1).to_string()
		})
		.unwrap_or_else(|_| "1".to_string());

	println!("cmake prepared with {} jobs", jobs);
	// assert!(
	// 	std::path::Path::new(PROJECT_BUILD).join("Makefile").exists()
	// 		|| std::path::Path::new(PROJECT_BUILD).join("build.ninja").exists(),
	// 	"CMake was not configured: no Makefile or build.ninja found"
	// );


    Command::new("cmake")
        .args([
            "--build",
            PROJECT_BUILD,
            "--target",
            format!("run_{}", loaded_project.project_name).as_str(),
			"--parallel",
			&jobs,
        ])
        .spawn()
        .unwrap();

    Ok(())
}

#[tauri::command]
fn build_config() {
    if let Some(project_mutex) = LOADED_PROJECT.get() {
        let project = project_mutex.lock().unwrap();
        match project.build_project_artery_configuration() {
            Ok(_) => (),
            Err(e) => println!("Can't build project configuration: {}", e),
        }
        println!("Done !\n")
    } else {
        println!("Can't build project")
    }
}

#[tauri::command]
fn create_new_project(
    window: tauri::Window,
    project_name: &str,
    artery_path: &str,
) -> Result<(), String> {
    println!("Creating new project '{}': '{}'", project_name.to_string(), artery_path.to_string());
    let new_project = Project::new(project_name.to_string(), artery_path.to_string());
    new_project
		.save_project_settings()
		.map_err(|e| e.to_string())?;
    match LOADED_PROJECT.get() {
        Some(project_mutex) => match project_mutex.lock() {
            Ok(mut project) => project.merge(new_project),
            Err(e) => println!("Can't lock project mutex: {}", e),
        },
        None => (),
    }
    window.close().unwrap();
    Ok(())
}

#[tauri::command]
async fn get_loaded_project() -> Option<Project> {
    match LOADED_PROJECT.get() {
        Some(project_mutex) => match project_mutex.lock() {
            Ok(project) => Some(project.clone()),
            Err(e) => {
                println!("{}", e.to_string());
                None
            }
        },
        None => None,
    }
}

#[tauri::command]
async fn load_project(path: &str) -> Result<(), String> {
    println!("Loading project at {}", path);

    let project = Project::load_project_settings(path.to_owned()).map_err(|e| e.to_string())?;
    let project_mutex = LOADED_PROJECT.get_or_init(|| Mutex::new(project.clone()));

    let mut project_guard = project_mutex.lock().unwrap();
    project_guard.merge(project);

    Ok(())
}

#[tauri::command]
async fn save_project(project: Project) -> Result<(), String> {
    println!("Saving project: {:#?}", project);
    project.save_project_settings().unwrap();

    let project_mutex = LOADED_PROJECT.get_or_init(|| Mutex::new(project.clone()));

    let mut project_guard = project_mutex.lock().unwrap();
    project_guard.merge(project);

    Ok(())
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            compile_artery,
            build_config,
            create_new_project,
            get_loaded_project,
            load_project,
            save_project,
        ]).setup(|app| {
            //TODO: own setup function do not let it in main file
            let window = app.get_window("main").unwrap();

            window.clone().listen_global("new_project",move | _event| {
                match create_new_project_window(&(window).app_handle()) {
                    Ok(_) => (),
                    Err(e) => println!("Can't create new project window: {}", e)
                }
            });

            Ok(())
        })
        .menu(create_menu_bar())
        .on_menu_event(create_menu_even_listener())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
