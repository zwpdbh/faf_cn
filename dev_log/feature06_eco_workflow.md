# Eco Workflow 

## Goal 

User simulate eco expansion by building workflow.

## Workflow UI 

- Node type 
  - Initial Node -- represent the initial status of the game.
  - Unit Node -- represent the FAF unit that could be build. 

- There should be only one initial node (call it Init Node), let user specify eco status:
  - `mass_in_storage`
  - `energy_in_storage`
  - `mass_per_sec`
  - `energy_per_sec`
  - `build_power`
- From Init Node, user could connect to other Unit Node:
  - Unit node is a node correponding to a FAF unit.
  - User double click the Unit node to change the unit.
  - The node icon should reflect the current unit. 
  - By default, the unit node's unit is t1 engineer.
- Unit Node could connect to other Unit Node
- The connection between nodes is one direction.


 ## Workflow Execution 

 - User click `Run` button to start to run the workflow.
 - We need to display following info on node and edge 
   - Display finished time on Unit Node.
   - Display eco status on edge (mouse hover to see a card)

## References 

- Study how to use [LiveFlow](https://hexdocs.pm/live_flow/LiveFlow.html) to simulate the build eco. 
  - [LiveFlow Demos](https://demo-flow.rocket4ce.com/)