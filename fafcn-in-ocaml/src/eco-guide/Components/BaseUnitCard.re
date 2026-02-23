open React;
open Models;
open Eco;

[@react.component]
let make = (~base_unit: UnitModel.t) => {
  <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <div className="flex items-center justify-between mb-3">
      <h2 className="text-lg font-semibold text-gray-900">
        {string("Base Unit (Engineer)")}
      </h2>
      <span
        className={"px-2 py-1 text-xs font-medium rounded-full " ++ UnitModel.faction_badge_class(base_unit)}>
        {string(Faction.to_string(base_unit.faction))}
      </span>
    </div>
    <div className="flex items-center space-x-4">
      <div
        className={"w-16 h-16 rounded-lg flex items-center justify-center shadow-inner overflow-hidden " ++ UnitModel.faction_bg_class(base_unit)}>
        <div className={"unit-icon-" ++ base_unit.unit_id ++ " w-14 h-14"} />
      </div>
      <div className="flex-1">
        <div className="flex items-center space-x-2">
          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800">
            {string(UnitModel.tech_badge(base_unit))}
          </span>
          <h3 className="font-semibold text-gray-900"> {string(base_unit.unit_id)} </h3>
        </div>
        <p className="text-sm text-gray-600"> {string(UnitModel.display_name(base_unit))} </p>
        <div className="mt-1 flex items-center space-x-4 text-xs text-gray-500">
          <span> {string("Mass: " ++ Calculator.format_number(base_unit.build_cost_mass))} </span>
          <span> {string("Energy: " ++ Calculator.format_number(base_unit.build_cost_energy))} </span>
          <span> {string("BT: " ++ Calculator.format_number(base_unit.build_time))} </span>
        </div>
      </div>
    </div>
  </div>;
};
