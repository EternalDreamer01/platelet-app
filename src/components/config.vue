<script setup>
import { invoke } from "@tauri-apps/api/tauri";
import { open } from '@tauri-apps/api/dialog';


const emit = defineEmits(["update"]);

const props = defineProps({ data: { type: Object, default: {} } });
const config = ref(props.data);
const custom_config_file = ref(false);

async function pick_file(filter_name, filter_extensions) {
  const file = await open({
    multiple: false,
    directory: false,
    filters: [{
      name: filter_name,
      extensions: filter_extensions
    }]
  });
  if (file) {
    return file;
  }
}

async function pick_file_osm() {
  config.value.map_path = await pick_file('osm', ['osm']);
};

async function pick_file_omnetpp() {
  config.value.config_template_paths.omnetpp_path = await pick_file('omnetpp.ini', ['ini']);
}

async function pick_file_sumo() {
  config.value.config_template_paths.sumocfg_path = await pick_file('sumocfg', ['sumocfg, cfgi']);
}

async function pick_file_services() {
  config.value.config_template_paths.services_path = await pick_file('xml', ['xml']);
}

const formatPickFile = (path) => {
  let result = "";
  if (path != "" && path != undefined) {
    result = path.split("/");
    result = result[result.length - 1];
  }
  return result;
}

const osmPathFormatted = computed(() => {
  return formatPickFile(config.value.map_path);
})


</script>

<template>
  <div id="scenario_configuration">
    <h1 class="text-lg font-bold"> Scenario Configuration </h1>
    <div class="flex gap-3 items-center">
      <UButton type="button" @click="pick_file_osm"> pick osm map file </UButton>
      <p class="grow"> {{ osmPathFormatted }} </p>
    </div>
    <p>Trips number:</p>
    <UInput v-model.number="config.vehicle_number" />
    <p> Cam Generation Time</p>
    <UInput v-model.number="config.gen_time"></UInput>
    <UCheckbox class="flex gap-3" v-model="custom_config_file" name="custom_config"
      label="Custom Configuration files" />
    <div v-if="custom_config_file">
      <div class="flex gap-3 items-center">
        <UButton type="button" @click="pick_file_omnetpp"> pick omnetpp config file </UButton>
        <p class="grow"> {{ config.config_template_paths.omnetpp_path }} </p>
      </div>
      <div class="flex gap-3 items-center">
        <UButton type="button" @click="pick_file_sumo"> pick sumocfg config file </UButton>
        <p class="grow"> {{ config.config_template_paths.sumocfg_path }} </p>
      </div>
      <div class="flex gap-3 items-center">
        <UButton type="button" @click="pick_file_services"> pick services config file </UButton>
        <p class="grow"> {{ config.config_template_paths.services_path }} </p>
      </div>
    </div>
    <h1 class="text-lg font-bold"> Security Configuration</h1>
    <p> Root Certificate </p>
    <UInput v-model.number="config.security_configuration.root_authority_number" />
    <p> Enrollment authority (per Root) </p>
    <UInput v-model.number="config.security_configuration.aa_per_root" />
    <p> Pseudonym certificate (per EA) </p>
    <UInput v-model.number="config.security_configuration.ticket_per_aa" />

  </div>
</template>
