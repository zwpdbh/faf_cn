open React;

[@react.component]
let make = () => {
  <div className="p-8 text-center">
    <h1 className="text-3xl font-bold text-blue-600">{string("Test Component")}</h1>
    <p className="mt-4 text-gray-600">{string("If you see this, React is working!")}</p>
  </div>;
};
