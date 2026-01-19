<script setup>
import { invoke, isTauri } from "@tauri-apps/api/core";
import { ref, onMounted } from "vue";
import { open } from '@tauri-apps/plugin-dialog';

const name = ref("");
const artery_path = ref("No File Selected");

async function pick_folder() {
  // Open a dialog
  const file = await open({
    multiple: false,
    directory: true,
  });
  if (file) {
    artery_path.value = file;
  }
}


async function create_project() {
	const listenEventSaved = await listen('projectSaved', async () => {
		try {
			if (!isTauri) {
				console.log('Not running inside Tauri, skipping invoke');
				return;
			}
			await invoke("create_new_project", {projectName: name.value, arteryPath: artery_path.value});
		}
		catch(e) {
			console.error(e);
		}
	})
}
</script>

<template>
    <div>

        <UInput v-model="name" placeholder="Enter your project name" />

      <div class="flex gap-3 items-center">
        <UButton label="Pick artery folder" @click="pick_folder"/>
        <p> {{ artery_path }} </p>
      </div>
        <UButton @click="create_project">Create Project</UButton>

    </div>

</template>

<style scoped>
        #wrapper{
            padding: 0;
            margin: 0;
            width: 100%;
            height: 100%;
        }
        #wrapper input {
          display: block;
        }
        #wrapper button {
          display: block;
        }
        #wrapper p {
          display: block;
        }
</style>