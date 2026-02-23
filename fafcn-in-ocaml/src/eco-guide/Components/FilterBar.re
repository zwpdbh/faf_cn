open React;
open Models;

[@react.component]
let make = (~active_filters: list(string), ~on_toggle: string => unit, ~on_clear: unit => unit) => {
  let filters = Filter.all_filters();
  let has_filters = active_filters != [];

  <div className="flex flex-wrap gap-2 mb-4">
    {filters
     |> List.map((filter: Filter.t) => {
          let is_active = List.mem(filter.key, active_filters);
          let class_name =
            is_active
              ? "px-3 py-1.5 rounded text-sm font-medium transition-all bg-indigo-500 text-white shadow-md"
              : "px-3 py-1.5 rounded text-sm font-medium transition-all bg-white/90 text-gray-700 hover:bg-white hover:shadow";
          <button
            key={filter.key}
            className=class_name
            onClick={_ => on_toggle(filter.key)}>
            {string(filter.label)}
          </button>;
        })
     |> Array.of_list |> React.array}
    {has_filters
       ? <button
           className="px-3 py-1.5 rounded text-sm font-medium bg-gray-500/50 text-white hover:bg-gray-500/70 transition-all"
           onClick={_ => on_clear()}>
           {string("Clear All")}
         </button>
       : React.null}
  </div>;
};
