<script setup>
import { onMounted } from "vue";
import { invoke, isTauri } from "@tauri-apps/api/core";
import { open } from '~/components/open';
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
	try {
		if (!isTauri) {
			console.log('Not running inside Tauri, skipping invoke');
			return;
		}
		await pick_file();
		// await invoke('load_project', { path: projectPath.value})
		window.location = "http://localhost:3000/loaded_project";
	}
	catch(e) {
		console.error(e)
	}
}

async function new_project() {
//   emit("new_project", {});
}

</script>

<template>
    <div class="h-screen flex items-center justify-center overlay">
        <div class="flex gap-4">
            <div>
                <button label="" @click="new_project">New Project</button>

            </div>
            <div>
                <button label="Load Project" @click="load_project">Load Project</button>

            </div>
        </div>
    </div>


</template>