open React;

type route =
  | Home
  | EcoGuide
  | EcoWorkflow;

let route_to_string = route =>
  switch (route) {
  | Home => "/"
  | EcoGuide => "/eco-guide"
  | EcoWorkflow => "/eco-workflow"
  };

let string_to_route = path => {
  let path =
    if (String.length(path) > 0 && path.[0] == '#') {
      String.sub(path, 1, String.length(path) - 1);
    } else {
      path;
    };
  switch (path) {
  | "/eco-guide" => EcoGuide
  | "/eco-workflow" => EcoWorkflow
  | _ => Home
  };
};

let push_route = route => {
  let hash = "#" ++ route_to_string(route);
  let loc = Webapi.Dom.window |> Webapi.Dom.Window.location;
  Webapi.Dom.Location.setHash(loc, hash);
};

[@react.component]
let make = (~current_route, ~on_navigate, ~children) => {
  let is_home = current_route == Home;

  <div className="min-h-screen bg-gray-50">
    <nav className="bg-white shadow-sm border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center gap-6">
            <button
              onClick={_ => on_navigate(Home)}
              className="text-xl font-bold text-gray-900 hover:text-blue-600 transition-colors">
              {string("FAF CN")}
            </button>
            {!is_home
               ? <>
                   <span className="text-gray-300"> {string("|")} </span>
                   <div className="flex items-center gap-4">
                     <button
                       onClick={_ => on_navigate(EcoGuide)}
                       className={
                         "text-sm font-medium transition-colors "
                         ++ (
                           current_route == EcoGuide
                             ? "text-blue-600"
                             : "text-gray-600 hover:text-gray-900"
                         )
                       }>
                       {string("Eco Guide")}
                     </button>
                     <button
                       onClick={_ => on_navigate(EcoWorkflow)}
                       className={
                         "text-sm font-medium transition-colors "
                         ++ (
                           current_route == EcoWorkflow
                             ? "text-blue-600"
                             : "text-gray-600 hover:text-gray-900"
                         )
                       }>
                       {string("Eco Workflow")}
                     </button>
                   </div>
                 </>
               : React.null}
          </div>
          {!is_home
             ? <div className="flex items-center">
                 <button
                   onClick={_ => on_navigate(Home)}
                   className="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                   {string("Back to Home")}
                 </button>
               </div>
             : React.null}
        </div>
      </div>
    </nav>
    children
  </div>;
};
