open React;
open Models;

[@react.component]
let make = (~units: list(UnitModel.t), ~base_unit: UnitModel.t, ~selected_ids: list(string), ~on_toggle: UnitModel.t => unit) => {
  <div className="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-3 mt-4">
    {units
     |> List.map((unit: UnitModel.t) => {
          let is_selected = List.mem(unit.unit_id, selected_ids);
          let is_engineer = unit.unit_id == base_unit.unit_id;
          let border_class =
            is_engineer
              ? "ring-2 ring-yellow-400 ring-offset-1 cursor-default"
              : is_selected
                  ? "ring-2 ring-indigo-500 ring-offset-1"
                  : "hover:ring-2 hover:ring-gray-300 hover:ring-offset-1 cursor-pointer";

          <button
            key={unit.unit_id}
            className={"group relative aspect-square rounded-lg p-1 transition-all duration-150 flex flex-col items-center justify-center text-center overflow-hidden " ++ UnitModel.faction_bg_class(unit) ++ " " ++ border_class}
            onClick={_ => !is_engineer ? on_toggle(unit) : ()}
            disabled=is_engineer
            title={unit.description}>
            <div className={"unit-icon-" ++ unit.unit_id} />
            {is_engineer
               ? <span className="absolute -top-1 -right-1 w-4 h-4 bg-yellow-400 rounded-full flex items-center justify-center z-10">
                   <span className="text-[8px] font-bold text-yellow-900"> {string("★")} </span>
                 </span>
               : is_selected
                   ? <span className="absolute -top-1 -right-1 w-4 h-4 bg-indigo-500 rounded-full flex items-center justify-center z-10">
                       <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                         <path
                           fillRule="evenodd"
                           d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                           clipRule="evenodd"
                         />
                       </svg>
                     </span>
                   : React.null}
          </button>;
        })
     |> Array.of_list |> React.array}
  </div>;
};
