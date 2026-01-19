<script setup>
import { ref, onMounted } from "vue";
import { invoke, isTauri } from "@tauri-apps/api/core";
import { useProjectStore } from "~/stores/projectStore";

const projectStore = useProjectStore();

async function compile_artery() {
	if (!isTauri) {
		console.log('Not running inside Tauri, skipping invoke');
		return;
	}
	try {
		// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
		await invoke("compile_artery").catch((error) => console.error(error));
	}
	catch(e) {
		console.error(e);
	}
}


async function build_config() {
	if (!isTauri) {
		console.log('Not running inside Tauri, skipping invoke');
		return;
	}
	try {
		await invoke('save_project', {project: projectStore.project}).catch((error) => console.log(error));
		await invoke("build_config").catch((error) => console.error(error));
	}
	catch(e) {
		console.error(e);
	}
}
</script>

<template>
    <UButton @click="build_config" label = "Build Config"/>
  <UButton @click="compile_artery" label="Compile"/>


</template>
