import { defineStore } from "pinia";

export const useProjectStore = defineStore('projectStore',  {
    state: () => {
        return { project: { foo: "bar" } };
    },
    getters: (state) => {
        return state.project;
    },
    actions: {
        updateProject(project) {
            this.project = project;
        }
    }
})