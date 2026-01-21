<script setup>
import { invoke } from '@tauri-apps/api';
import { open } from '@tauri-apps/api/dialog';
import { emit } from '@tauri-apps/api/event'

const projectPath = ref("");

async function pick_file() {
  // Open a dialog
  const file = await open({
    multiple: false,
    directory: false,
    filters: [{
    name: 'platelet',
    extensions: ['platelet']
  }]
  });
  if (file) {
    return projectPath.value = file
  }
}

async function load_project() {
    pick_file()
    .then(() => { invoke('load_project', { path: projectPath.value}).then(() => {window.location = "http://localhost:3000/loaded_project"}, (error) => { console.log(error)})});
}

async function new_project() {
  emit("new_project", {});
}

</script>

<template>
    <div class="h-screen flex items-center justify-center overlay">
        <div class="flex gap-4">
            <div>
                <UButton label="New Project" @click="new_project"></UButton>

            </div>
            <div>
                <UButton label="Load Project" @click="load_project"></UButton>

            </div>
        </div>
    </div>


</template>