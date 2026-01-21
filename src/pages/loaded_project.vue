
<script setup>
// This starter template is using Vue 3 <script setup> SFCs
// Check out https://vuejs.org/api/sfc-script-setup.html#script-setup
import { invoke } from "@tauri-apps/api";
import Compile from "~/components/compile.vue";
import Config from "~/components/config.vue";
import { listen } from '@tauri-apps/api/event';
import { useProjectStore } from "~/stores/projectStore";

const projectStore = useProjectStore();
await invoke('get_loaded_project').catch((error) => { console.log(error)}).then((value) => {
  projectStore.updateProject(value);
});
const listenEventLoaded = await listen('projectLoaded', (event) => { projectStore.project = event.payload})
const listenEventSaved = await listen('projectSaved', () => {
  invoke('save_project', {project: projectStore.project}).catch((error) => console.log(error))
})
const onUpdate = (config) => {
  projectStore.updateProjec(config);
}

</script>

<template>

  <h1 class="text-2xl font-bold"> Project name: {{ projectStore.project.project_name }} </h1>
  <div class="grid grid-cols-2">
    <div>
      <Config :data="projectStore.project" @update="onUpdate"/>
    </div>
    <div class="absolute bottom-10 right-10">
      <Compile/>
    </div>
  </div>
</template>
