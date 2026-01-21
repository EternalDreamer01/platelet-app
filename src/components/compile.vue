<script setup>
import { ref } from "vue";
import { invoke } from "@tauri-apps/api/tauri";
import { useProjectStore } from "~/stores/projectStore";

const projectStore = useProjectStore();

async function compile_artery() {
  // Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
  await invoke("compile_artery").catch((error) => console.error(error));
}


async function build_config() {
  await invoke('save_project', {project: projectStore.project}).catch((error) => console.log(error));
  invoke("build_config").catch((error) => console.error(error));
}
</script>

<template>
    <UButton @click="build_config" label = "Build Config"/>
  <UButton @click="compile_artery" label="Compile"/>


</template>
