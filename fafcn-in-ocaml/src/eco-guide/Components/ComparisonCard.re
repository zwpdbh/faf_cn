open React;
open Models;
open Eco;

[@react.component]
let make = (~unit: UnitModel.t, ~ratio: Calculator.ratio) => {
  <div className="bg-gray-50 rounded-lg p-2 border border-gray-200">
    <div className="flex items-center gap-2 mb-2">
      <div className={"w-8 h-8 rounded shrink-0 overflow-hidden relative " ++ UnitModel.faction_bg_class(unit)}>
        <div
          className={"unit-icon-" ++ unit.unit_id ++ " absolute"}
          style={ReactDOM.Style.make(~width="64px", ~height="64px", ~transform="scale(0.5)", ~transformOrigin="top left", ())}
        />
      </div>
      <div className="flex-1 min-w-0">
        <span className="text-xs font-medium text-gray-900 truncate">
          {string(UnitModel.display_name(unit))}
        </span>
      </div>
      <span className={"px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0 " ++ Calculator.ratio_badge_class(ratio.mass)}>
        {string(Calculator.mass_formatted(ratio))}
      </span>
    </div>
    <div className="grid grid-cols-3 gap-2 text-xs">
      <div className="text-center">
        <span className="block text-gray-400"> {string("Mass")} </span>
        <span className={Calculator.ratio_color(ratio.mass)}>
          {string(Calculator.mass_formatted(ratio))}
        </span>
      </div>
      <div className="text-center">
        <span className="block text-gray-400"> {string("Energy")} </span>
        <span className={Calculator.ratio_color(ratio.energy)}>
          {string(Calculator.energy_formatted(ratio))}
        </span>
      </div>
      <div className="text-center">
        <span className="block text-gray-400"> {string("Time")} </span>
        <span className={Calculator.ratio_color(ratio.build_time)}>
          {string(Calculator.build_time_formatted(ratio))}
        </span>
      </div>
    </div>
  </div>;
};
