<script setup>
import { invoke } from "@tauri-apps/api";
import { ref } from "vue";
import { open } from '@tauri-apps/api/dialog';

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
    invoke("create_new_project", {projectName: name.value, arteryPath: artery_path.value}).catch((error) => console.error(error));
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