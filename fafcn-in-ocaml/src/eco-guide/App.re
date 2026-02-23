open React;

type route =
  | Home
  | EcoGuide
  | EcoWorkflow;

[@react.component]
let make = () => {
  let (current_route, set_route) = useState(() => Home);

  let navigate = route => set_route(_ => route);

  <div className="min-h-screen bg-gray-50">
    {switch (current_route) {
     | Home => <Home on_navigate={route =>
         switch (route) {
         | "eco-guide" => navigate(EcoGuide)
         | "eco-workflow" => navigate(EcoWorkflow)
         | _ => ()
         }
       } />
     | EcoGuide =>
       <div>
         <nav className="bg-white shadow-sm border-b border-gray-200">
           <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
             <div className="flex justify-between h-16">
               <div className="flex items-center">
                 <button
                   onClick={_ => navigate(Home)}
                   className="text-xl font-bold text-gray-900 hover:text-blue-600 transition-colors">
                   {string("FAF CN")}
                 </button>
               </div>
               <div className="flex items-center">
                 <button
                   onClick={_ => navigate(Home)}
                   className="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                   {string("← Back to Home")}
                 </button>
               </div>
             </div>
           </div>
         </nav>
         <EcoGuide />
       </div>
     | EcoWorkflow =>
       <div>
         <nav className="bg-white shadow-sm border-b border-gray-200">
           <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
             <div className="flex justify-between h-16">
               <div className="flex items-center">
                 <button
                   onClick={_ => navigate(Home)}
                   className="text-xl font-bold text-gray-900 hover:text-blue-600 transition-colors">
                   {string("FAF CN")}
                 </button>
               </div>
               <div className="flex items-center">
                 <button
                   onClick={_ => navigate(Home)}
                   className="text-sm text-gray-500 hover:text-gray-900 transition-colors">
                   {string("← Back to Home")}
                 </button>
               </div>
             </div>
           </div>
         </nav>
         <div className="max-w-7xl mx-auto px-4 py-12 text-center">
           <h1 className="text-3xl font-bold text-gray-900 mb-4">
             {string("Eco Workflow")}
           </h1>
           <p className="text-gray-600">{string("Coming soon...")}</p>
         </div>
       </div>
     }}
  </div>;
};
