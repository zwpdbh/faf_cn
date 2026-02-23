open React;
open Models;

[@react.component]
let make = (~selected: Faction.t, ~on_select: Faction.t => unit) => {
  let tab = (faction, label, active_class) => {
    let is_active = selected == faction;
    let class_name =
      "whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm capitalize transition-colors "
      ++ (is_active ? active_class : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300");
    <button className=class_name onClick={_ => on_select(faction)}>
      {string(label)}
    </button>;
  };

  <div className="border-b border-gray-200">
    <nav className="-mb-px flex space-x-8" ariaLabel="Tabs">
      {tab(Faction.Uef, "UEF", "border-blue-500 text-blue-600")}
      {tab(Faction.Cybran, "CYBRAN", "border-red-500 text-red-600")}
      {tab(Faction.Aeon, "AEON", "border-emerald-500 text-emerald-600")}
      {tab(Faction.Seraphim, "SERAPHIM", "border-violet-500 text-violet-600")}
    </nav>
  </div>;
};
