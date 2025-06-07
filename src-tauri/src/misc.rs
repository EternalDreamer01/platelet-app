use std::{
    fs::{self, create_dir},
    path::Path,
    sync::Mutex,
};

use tauri::{
    api::dialog::FileDialogBuilder, CustomMenuItem, Manager, Menu, Runtime, Submenu, Window, WindowBuilder, WindowMenuEvent
};

use crate::{project::Project, LOADED_PROJECT};

pub fn folder_exist<P: AsRef<Path>>(path: P) -> bool {
    match fs::metadata(path) {
        Ok(metadata) => {
            if metadata.is_dir() {
                true
            } else {
                false
            }
        }
        Err(_) => false,
    }
}

pub fn create_folder_if_not_exist<P: AsRef<Path>>(path: P) -> Result<(), std::io::Error> {
    if !folder_exist(&path) {
        return create_dir(&path);
    }
    Ok(())
}

pub fn create_new_project_window<R: Runtime, M: Manager<R>>(manager: &M) -> Result<Window<R>, tauri::Error> {
    WindowBuilder::new(
        manager,
        "new_project",
        tauri::WindowUrl::App("new_project".into()),
    )
    .build()
}

pub fn create_menu_bar() -> Menu {
    //TODO: change other event name
    let new = CustomMenuItem::new("new_project_menu".to_string(), "New Project");
    let save = CustomMenuItem::new("save_project".to_string(), "Save Project");
    let load = CustomMenuItem::new("load_project".to_string(), "Load Project");
    let submenu = Submenu::new(
        "File",
        Menu::new().add_item(new).add_item(save).add_item(load),
    );
    Menu::new().add_submenu(submenu)
}

pub fn create_menu_even_listener() -> impl Fn(WindowMenuEvent) + Send + Sync + 'static {
    |event: WindowMenuEvent| {
        match event.menu_item_id() {
            "load_project" => FileDialogBuilder::new()
                .add_filter("Platelet configuration file .platelet", &["platelet"])
                .pick_file(move |folder_path| {
                    // do something with the optional folder path here
                    // the folder path is `None` if the user closed the dialog
                    match folder_path {
                        Some(path) => {
                            let project =
                                Project::load_project_settings(path.to_str().unwrap().to_owned())
                                    .unwrap();
                            let project_mutex =
                                LOADED_PROJECT.get_or_init(|| Mutex::new(project.clone()));

                            let mut project_guard = project_mutex.lock().unwrap();
                            project_guard.merge(project);

                            event
                                .window()
                                .emit_all("projectLoaded", LOADED_PROJECT.get().unwrap())
                                .unwrap();
                        }
                        None => (),
                    };
                }),
            "new_project_menu" => {
                match create_new_project_window(&event.window().app_handle())
                {
                    Ok(_) => println!("new_project window created"),
                    Err(e) => println!("Can't create create_project window: {}", e),
                }
            }
            "save_project" => {
                event
                    .window()
                    .emit_all("projectSaved", "save project")
                    .unwrap();
            }
            _ => {}
        };
    }
}
