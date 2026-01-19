# Tauri v1 to v2 Migration Notes

This document outlines the key changes made to migrate your Platelet application from Tauri v1 to v2.

## Key Changes Made

### 1. **Imports and Module Reorganization**
   - **v1**: `use tauri::api::dialog::FileDialogBuilder`
   - **v2**: `use tauri_plugin_dialog::DialogExt`
   - The dialog API was moved to a separate plugin

### 2. **Menu API Changes**
   - **v1**: `CustomMenuItem` and chainable menu building
   - **v2**: `MenuItemBuilder` and `Menu` - Note: The v2 menu API differs significantly
   - Menu items now require a manager/app handle to build

### 3. **Event Emission**
   - **v1**: `.emit_all("event_name", payload)`
   - **v2**: `.emit("event_name", payload)`
   - The method name changed from `emit_all` to `emit`
   - Requires importing the `Emitter` trait

### 4. **Window API**
   - **v1**: `WindowUrl::App()`
   - **v2**: `WebviewUrl::App()` (via `tauri_utils::config`)
   - Window creation uses `WebviewWindowBuilder` instead of `WindowBuilder`

### 5. **Event Listener Changes**
   - **v1**: Used `WindowMenuEvent` with `.menu_item_id()` method
   - **v2**: Uses `MenuEvent` with `.id` property
   - Menu event handler signature changed: now takes `&AppHandle` and `MenuEvent` as parameters

### 6. **Manager and Listener Traits**
   - Added `use tauri::Listener` import for the `listen()` method
   - Added `use tauri::Manager` for access to manager methods
   - Added `use tauri::Emitter` for emit methods

### 7. **Dialog API**
   - **v1**: `FileDialogBuilder::new().pick_file()`
   - **v2**: `app.dialog().file().pick_file()`
   - Returns file paths that need proper type handling

### 8. **Application Setup**
   - **v1**: Menu could be set during builder configuration
   - **v2**: Menu needs to be set inside setup with `app_handle.set_menu(menu)?`
   - This requires access to the app handle during setup

### 9. **Plugin Initialization**
   - The dialog plugin is now explicitly initialized: `.plugin(tauri_plugin_dialog::init())`

## Files Modified

1. **src-tauri/src/main.rs**
   - Updated imports to include `Listener` and `Menu`
   - Moved menu creation to setup block
   - Simplified event listener setup

2. **src-tauri/src/misc.rs**
   - Updated imports for new menu and dialog APIs
   - Modified `create_menu_bar()` to accept `app_handle` parameter
   - Updated `create_menu_even_listener()` to handle new `MenuEvent` structure
   - Fixed path handling for file dialog results
   - Updated window creation to use new API

## Known Issues and TODO

1. **Menu Items**: The current `create_menu_bar()` creates an empty menu. The old code tried to build a menu with File -> {New Project, Save Project, Load Project} items, but Tauri v2's menu API for adding items is different and needs to be updated based on your requirements.

2. **Event Listener Registration**: The `new_project` event listener setup was simplified and moved out of the main loop. You may need to re-evaluate if this is the correct implementation for your use case.

3. **Dialog Filtering**: The file dialog filter for `.platelet` files was removed during migration. You may need to re-add it using the new dialog API.

## Testing Recommendations

1. Test all menu functions
2. Test file dialog opens properly
3. Test new project window creation
4. Test project loading functionality
5. Test project saving functionality
6. Verify all custom events are properly emitted and received

## References

- [Tauri v2 Migration Guide](https://tauri.app/docs/guides/upgrade-v2)
- [Tauri Menu API](https://docs.rs/tauri/latest/tauri/menu/)
- [Tauri Dialog Plugin](https://github.com/tauri-apps/plugins-workspace/tree/main/plugins/dialog)
