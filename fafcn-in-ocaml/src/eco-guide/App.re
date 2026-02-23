open React;

[@mel.scope "window"]
external add_event_listener: (string, Dom.event => unit) => unit = "addEventListener";

[@mel.scope "window"]
external remove_event_listener: (string, Dom.event => unit) => unit = "removeEventListener";

[@react.component]
let make = () => {
  let (current_route, set_route) =
    useState(() => {
      let hash =
        Webapi.Dom.window
        |> Webapi.Dom.Window.location
        |> Webapi.Dom.Location.hash;
      Layout.string_to_route(hash);
    });

  // Listen for hash changes
  useEffect1(
    () => {
      let handle_hash_change = _ => {
        let hash =
          Webapi.Dom.window
          |> Webapi.Dom.Window.location
          |> Webapi.Dom.Location.hash;
        set_route(_ => Layout.string_to_route(hash));
      };

      add_event_listener("hashchange", handle_hash_change);

      Some(() => remove_event_listener("hashchange", handle_hash_change));
    },
    [|set_route|],
  );

  let navigate = route => {
    Layout.push_route(route);
    set_route(_ => route);
  };

  <Layout current_route on_navigate=navigate>
    {switch (current_route) {
     | Home => <Home on_navigate={route_str => navigate(Layout.string_to_route("/" ++ route_str))} />
     | EcoGuide => <EcoGuide />
     | EcoWorkflow =>
       <div className="max-w-7xl mx-auto px-4 py-12 text-center">
         <h1 className="text-3xl font-bold text-gray-900 mb-4">
           {string("Eco Workflow")}
         </h1>
         <p className="text-gray-600"> {string("Coming soon...")} </p>
       </div>
     }}
  </Layout>;
};
