open React;
open Models;
open Data;

// State and actions
type state = {
  selected_faction: Faction.t,
  active_filters: list(string),
  selected_units: list(UnitModel.t),
};

type action =
  | SelectFaction(Faction.t)
  | ToggleFilter(string)
  | ToggleUnit(UnitModel.t)
  | ClearFilters
  | ClearSelections;

let initial_state = {
  selected_faction: Faction.Uef,
  active_filters: [],
  selected_units: [],
};

let reducer = (state, action) =>
  switch (action) {
  | SelectFaction(faction) => {
      selected_faction: faction,
      active_filters: [],
      selected_units: [],
    }
  | ToggleFilter(filter) =>
    let new_filters =
      if (List.mem(filter, state.active_filters)) {
        List.filter(f => f != filter, state.active_filters);
      } else {
        // Remove other filters from same group
        let to_remove =
          Models.Filter.is_usage_filter(filter)
            ? Models.Filter.usage_filters
            : Models.Filter.is_tech_filter(filter)
                ? Models.Filter.tech_filters : [];
        [
          filter,
          ...List.filter(f => !List.mem(f, to_remove), state.active_filters),
        ];
      };
    {
      ...state,
      active_filters: new_filters,
    };
  | ToggleUnit(unit) =>
    let base_id = Faction.engineer_id(state.selected_faction);
    if (unit.UnitModel.unit_id == base_id) {
      state;
    } else {
      let new_selected =
        if (List.exists(
              u => u.UnitModel.unit_id == unit.unit_id,
              state.selected_units,
            )) {
          List.filter(
            u => u.UnitModel.unit_id != unit.unit_id,
            state.selected_units,
          );
        } else {
          [unit, ...state.selected_units];
        };
      {
        ...state,
        selected_units: new_selected,
      };
    };
  | ClearFilters => {
      ...state,
      active_filters: [],
    }
  | ClearSelections => {
      ...state,
      selected_units: [],
    }
  };

[@react.component]
let make = () => {
  let (state, dispatch) = React.useReducer(reducer, initial_state);

  let base_unit = {
    let id = Faction.engineer_id(state.selected_faction);
    Units_data.find_unit(id) |> Option.get;
  };

  let faction_units =
    Units_data.all_units()
    |> List.filter(u => u.UnitModel.faction == state.selected_faction)
    |> List.sort((a, b) => String.compare(a.UnitModel.unit_id, b.unit_id));

  let filtered_units =
    if (state.active_filters == []) {
      faction_units;
    } else {
      List.filter(
        UnitModel.matches_filters(state.active_filters),
        faction_units,
      );
    };

  let selected_ids =
    List.map((u: UnitModel.t) => u.unit_id, state.selected_units);

  <div className="eco-guide max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
    // Header

      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">
          {string("Eco Guides")}
        </h1>
        <p className="mt-2 text-gray-600">
          {string(
             "Select units to compare their economy costs against the faction's T1 Engineer.",
           )}
        </p>
      </div>
      // Faction Tabs
      <div className="mb-6">
        <FactionTabs
          selected={state.selected_faction}
          on_select={f => dispatch(SelectFaction(f))}
        />
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        // Left Column: Unit Selection

          <div className="lg:col-span-8 space-y-6">
            <BaseUnitCard base_unit />
            <div
              className="unit-selection-grid rounded-lg shadow-sm border border-gray-200 p-4"
              style={ReactDOM.Style.make(
                ~backgroundImage="url('/images/units/background.jpg')",
                ~backgroundSize="cover",
                ~backgroundPosition="center",
                (),
              )}>
              <div className="flex items-center justify-between mb-4">
                <h2
                  className="text-lg font-semibold text-white drop-shadow-md">
                  {string("Select Units to Compare")}
                </h2>
                {state.selected_units != []
                   ? <button
                       className="text-sm bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded transition-colors shadow-md"
                       onClick={_ => dispatch(ClearSelections)}>
                       {string(
                          "Clear ("
                          ++ string_of_int(
                               List.length(state.selected_units),
                             )
                          ++ ")",
                        )}
                     </button>
                   : React.null}
              </div>
              <FilterBar
                active_filters={state.active_filters}
                on_toggle={f => dispatch(ToggleFilter(f))}
                on_clear={() => dispatch(ClearFilters)}
              />
              <UnitGrid
                units=filtered_units
                base_unit
                selected_ids
                on_toggle={u => dispatch(ToggleUnit(u))}
              />
              {filtered_units == []
                 ? <div className="text-center py-8 text-white/70">
                     <p> {string("No units match the selected filters.")} </p>
                     <button
                       className="mt-2 text-sm underline hover:text-white"
                       onClick={_ => dispatch(ClearFilters)}>
                       {string("Clear filters")}
                     </button>
                   </div>
                 : React.null}
            </div>
          </div>
          // Right Column: Eco Comparison
          <div className="lg:col-span-4 space-y-4">
            <EcoComparison base_unit selected_units={state.selected_units} />
          </div>
        </div>
    </div>;
};
