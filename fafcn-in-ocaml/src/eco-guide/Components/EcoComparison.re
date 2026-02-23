open React;
open Models;
open Eco;

[@react.component]
let make = (~base_unit: UnitModel.t, ~selected_units: list(UnitModel.t)) => {
  let comparisons = Calculator.generate_engineer_comparisons(base_unit, selected_units);
  let has_selections = selected_units != [];
  let has_multiple = List.length(selected_units) >= 2;
  let cross_comparisons =
    has_multiple
      ? Calculator.generate_tiered_cross_comparisons(base_unit, selected_units)
      : [];

  <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <h2 className="text-lg font-semibold text-gray-900 mb-4"> {string("Eco Comparison")} </h2>
    {!has_selections
       ? <EmptyState />
       : <div className="space-y-4">
           // Base unit comparison
           <div>
             <div className="bg-gray-100 rounded-lg p-2 mb-3 border border-gray-200">
               <div className="flex items-center gap-2 mb-2">
                 <div className={"w-8 h-8 rounded shrink-0 overflow-hidden relative " ++ UnitModel.faction_bg_class(base_unit)}>
                   <div
                     className={"unit-icon-" ++ base_unit.unit_id ++ " absolute"}
                     style={ReactDOM.Style.make(~width="64px", ~height="64px", ~transform="scale(0.5)", ~transformOrigin="top left", ())}
                   />
                 </div>
                 <div className="flex-1 min-w-0">
                   <span className="text-xs font-semibold text-gray-900 truncate">
                     {string(base_unit.description)}
                   </span>
                   <p className="text-[10px] text-gray-500"> {string(base_unit.unit_id)} </p>
                 </div>
               </div>
               <div className="grid grid-cols-3 gap-1 text-[10px] text-center">
                 <div className="bg-white rounded p-1">
                   <span className="block text-gray-400"> {string("Mass")} </span>
                   <span className="font-semibold text-gray-700">
                     {string(Eco.Calculator.format_number(base_unit.build_cost_mass))}
                   </span>
                 </div>
                 <div className="bg-white rounded p-1">
                   <span className="block text-gray-400"> {string("Energy")} </span>
                   <span className="font-semibold text-gray-700">
                     {string(Eco.Calculator.format_number(base_unit.build_cost_energy))}
                   </span>
                 </div>
                 <div className="bg-white rounded p-1">
                   <span className="block text-gray-400"> {string("BT")} </span>
                   <span className="font-semibold text-gray-700">
                     {string(Eco.Calculator.format_number(base_unit.build_time))}
                   </span>
                 </div>
               </div>
             </div>
             <div className="space-y-2">
               {comparisons
                |> List.map((comp: Eco.Calculator.comparison) =>
                     <ComparisonCard key={comp.unit.unit_id} unit={comp.unit} ratio={comp.ratio} />
                   )
                |> Array.of_list |> React.array}
             </div>
           </div>
           // Cross comparisons
           {has_multiple
              ? <div className="border-t pt-4">
                  <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
                    {string("Cross Comparisons")}
                  </h3>
                  <div className="space-y-3">
                    {cross_comparisons
                     |> List.map((cross: Eco.Calculator.cross_comparison) =>
                          <div key={cross.base_unit.unit_id} className="bg-gray-50 rounded-lg p-2 border border-gray-200">
                            <div className="flex items-center gap-2 mb-2 pb-2 border-b border-gray-200">
                              <div className={"w-6 h-6 rounded shrink-0 overflow-hidden relative " ++ UnitModel.faction_bg_class(cross.base_unit)}>
                                <div
                                  className={"unit-icon-" ++ cross.base_unit.unit_id ++ " absolute"}
                                  style={ReactDOM.Style.make(~width="64px", ~height="64px", ~transform="scale(0.375)", ~transformOrigin="top left", ())}
                                />
                              </div>
                              <div className="flex-1 min-w-0">
                                <span className="text-xs font-medium text-gray-700 truncate block">
                                  {string(UnitModel.display_name(cross.base_unit))}
                                </span>
                                <span className="text-[10px] text-gray-500">
                                  {string("Mass: " ++ Eco.Calculator.format_number(cross.base_unit.build_cost_mass))}
                                </span>
                              </div>
                            </div>
                            <div className="space-y-1.5">
                              {cross.comparisons
                               |> List.map(((target_unit: UnitModel.t, ratio)) =>
                                    <div key={target_unit.unit_id}>
                                      <div className="flex items-center justify-between py-1">
                                        <div className="flex items-center gap-2">
                                          <div className={"w-8 h-8 rounded shrink-0 overflow-hidden relative " ++ UnitModel.faction_bg_class(target_unit)}>
                                            <div
                                              className={"unit-icon-" ++ target_unit.unit_id ++ " absolute"}
                                              style={ReactDOM.Style.make(~width="64px", ~height="64px", ~transform="scale(0.5)", ~transformOrigin="top left", ())}
                                            />
                                          </div>
                                          <span className="text-xs text-gray-700 truncate">
                                            {string(UnitModel.display_name(target_unit))}
                                          </span>
                                        </div>
                                        <span className={"px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0 " ++ Calculator.ratio_badge_class(ratio.mass)}>
                                          {string(Calculator.mass_formatted(ratio))}
                                        </span>
                                      </div>
                                      <div className="grid grid-cols-3 gap-1 text-[10px] text-center">
                                        <div>
                                          <span className="block text-gray-400"> {string("Mass")} </span>
                                          <span className={Calculator.ratio_color(ratio.mass)}>
                                            {string(Calculator.mass_formatted(ratio))}
                                          </span>
                                        </div>
                                        <div>
                                          <span className="block text-gray-400"> {string("Energy")} </span>
                                          <span className={Calculator.ratio_color(ratio.energy)}>
                                            {string(Calculator.energy_formatted(ratio))}
                                          </span>
                                        </div>
                                        <div>
                                          <span className="block text-gray-400"> {string("Time")} </span>
                                          <span className={Calculator.ratio_color(ratio.build_time)}>
                                            {string(Calculator.build_time_formatted(ratio))}
                                          </span>
                                        </div>
                                      </div>
                                    </div>
                                  )
                               |> Array.of_list |> React.array}
                            </div>
                          </div>
                        )
                     |> Array.of_list |> React.array}
                  </div>
                </div>
              : React.null}
           // Summary stats
           <div className="border-t pt-4 mt-4">
             <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
               {string("Quick Stats")}
             </h3>
             <div className="grid grid-cols-2 gap-2 text-xs">
               <div className="bg-gray-50 rounded p-2">
                 <span className="block text-gray-500"> {string("Total Mass")} </span>
                 <span className="font-semibold text-gray-900">
                   {string(Eco.Calculator.format_number(Eco.Calculator.total_mass_cost(selected_units)))}
                 </span>
               </div>
               <div className="bg-gray-50 rounded p-2">
                 <span className="block text-gray-500"> {string("Total Energy")} </span>
                 <span className="font-semibold text-gray-900">
                   {string(Eco.Calculator.format_number(Eco.Calculator.total_energy_cost(selected_units)))}
                 </span>
               </div>
             </div>
           </div>
         </div>}
  </div>;
};
