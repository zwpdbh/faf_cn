# Eco Workflow 

## Goal 

- User could simulate expand eco then build something by building workflow.
- User setup initial resource nodes including
  - mass_in_storage
  - power_in_storage
  - mass_per_second
  - power_per_second
  - build_power 
- Given source nodes, they could be connected to build node
  - Its input must be resource nodes 
  - Its output could be 
    - orinary unit 
    - resource unit (as other build nodes inputs)
  - build node also record current time mark

- A workflow 
  - Resource nodes -> build node -> build orinary unit (finished)
  - Resource nodes -> build node -> resource nodes -> build node -> resource nodes -> build orinary unit (finished)
  

## References 

- Study how to use [LiveFlow](https://hexdocs.pm/live_flow/LiveFlow.html) to simulate the build eco. 
  - [LiveFlow Demos](https://demo-flow.rocket4ce.com/)