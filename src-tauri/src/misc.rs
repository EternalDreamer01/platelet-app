use std::{
    fs::{self, create_dir},
    path::Path,
    sync::Mutex,
};

use tauri::{
    menu::Menu,
    AppHandle, Wry, menu::MenuEvent, Manager, Emitter
};
use tauri_plugin_dialog::DialogExt;

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

pub fn create_new_project_window(app_handle: AppHandle<Wry>) -> Result<(), tauri::Error> {
    tauri::webview::WebviewWindowBuilder::new(&app_handle, "new_project", tauri::WebviewUrl::App("new_project".into()))
        .build()?;
    Ok(())
}

pub fn create_menu_bar(app_handle: &AppHandle<Wry>) -> Result<Menu<Wry>, tauri::Error> {
    // In Tauri v2, menus are created differently
    // For now, create an empty menu - you'll need to update this based on your needs
    Menu::new(app_handle)
}

pub fn create_menu_even_listener() -> impl Fn(&AppHandle<Wry>, MenuEvent) + Send + Sync + 'static {
    |app_handle: &AppHandle<Wry>, event: MenuEvent| {
        match event.id.as_ref() {
            "load_project" => {
                let app = app_handle.clone();
                let dialog = app.dialog();
                dialog.file().pick_file(move |folder_path| {
                    if let Some(path) = folder_path {
                        if let Some(path_str_borrowed) = path.as_path() {
                            let path_str = path_str_borrowed.to_string_lossy().into_owned();
                            let project =
                                Project::load_project_settings(path_str)
                                    .unwrap();
                            let project_mutex =
                                LOADED_PROJECT.get_or_init(|| Mutex::new(project.clone()));

                            let mut project_guard = project_mutex.lock().unwrap();
                            project_guard.merge(project);

                            let windows = app.webview_windows();
                            if let Some((_, window)) = windows.iter().next() {
                                let _ = window
                                    .emit("projectLoaded", LOADED_PROJECT.get().unwrap());
                            }
                        }
                    }
                });
            }
            "new_project_menu" => {
                match create_new_project_window(app_handle.clone())
                {
                    Ok(_) => println!("new_project window created"),
                    Err(e) => println!("Can't create create_project window: {}", e),
                }
            }
            "save_project" => {
                let windows = app_handle.webview_windows();
                if let Some((_, window)) = windows.iter().next() {
                    let _ = window
                        .emit("projectSaved", "save project");
                }
            }
            _ => {}
        };
    }
}
