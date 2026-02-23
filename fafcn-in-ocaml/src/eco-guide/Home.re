open React;

[@react.component]
let make = (~on_navigate: string => unit) => {
  <div
    className="min-h-[calc(100vh-4rem)] flex flex-col items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
    <div className="text-center max-w-2xl mx-auto">
      // Logo/Icon

        <div
          className="mx-auto w-24 h-24 bg-gradient-to-br from-blue-500 to-violet-600 rounded-2xl flex items-center justify-center shadow-lg mb-8">
          // Globe icon

            <svg
              className="w-14 h-14 text-white"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth="1.5">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 21a9.004 9.004 0 008.716-6.747M12 21a9.004 9.004 0 01-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 017.843 4.582M12 3a8.997 8.997 0 00-7.843 4.582m15.686 0A11.953 11.953 0 0112 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0121 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0112 16.5c-3.162 0-6.133-.815-8.716-2.247m0 0A9.015 9.015 0 013 12c0-1.605.42-3.113 1.157-4.418"
              />
            </svg>
          </div>
        // Title
        <h1 className="text-4xl sm:text-5xl font-bold text-gray-900 mb-4">
          {string("FAF CN")}
        </h1>
        <p className="text-lg text-gray-600 mb-8">
          {string(
             "Supreme Commander: Forged Alliance Forever - Community Tools",
           )}
        </p>
        // Navigation Cards
        <div className="grid grid-cols-1 gap-4 max-w-sm mx-auto">
          // Eco Guide Card

            <button
              onClick={_ => on_navigate("eco-guide")}
              className="group relative rounded-xl p-6 text-left transition-all hover:scale-[1.02] block w-full">
              <span
                className="absolute inset-0 rounded-xl bg-gradient-to-r from-blue-500/10 to-violet-500/10 border border-gray-300 group-hover:border-blue-400/50 transition-colors"
              />
              <span className="relative flex items-center gap-4">
                <span
                  className="shrink-0 w-12 h-12 rounded-xl bg-blue-500/10 flex items-center justify-center">
                  // Calculator icon

                    <svg
                      className="w-6 h-6 text-blue-600"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      strokeWidth="1.5">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M15.75 15.75l-2.489-2.489m0 0a3.375 3.375 0 10-4.773-4.773 3.375 3.375 0 004.774 4.774zM21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                  </span>
                <span>
                  <span className="block font-semibold text-gray-900">
                    {string("Eco Guide")}
                  </span>
                  <span className="block text-sm text-gray-500">
                    {string("Compare unit economy costs")}
                  </span>
                </span>
                // Chevron right icon
                <svg
                  className="w-5 h-5 text-gray-400 group-hover:text-blue-600 ml-auto transition-colors"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth="2">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M8.25 4.5l7.5 7.5-7.5 7.5"
                  />
                </svg>
              </span>
            </button>
            // Eco Workflow Card (placeholder)
            <button
              onClick={_ => on_navigate("eco-workflow")}
              className="group relative rounded-xl p-6 text-left transition-all hover:scale-[1.02] block w-full">
              <span
                className="absolute inset-0 rounded-xl bg-gradient-to-r from-emerald-500/10 to-teal-500/10 border border-gray-300 group-hover:border-emerald-400/50 transition-colors"
              />
              <span className="relative flex items-center gap-4">
                <span
                  className="shrink-0 w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center">
                  // Chart line icon

                    <svg
                      className="w-6 h-6 text-emerald-600"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                      strokeWidth="1.5">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M3.75 3v11.25A2.25 2.25 0 006 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0118 16.5h-2.25m-7.5 0h7.5m-7.5 0l-1 3m8.5-3l1 3m0 0l.5 1.5m-.5-1.5h-9.5m0 0l-.5 1.5M9 11.25v1.5M12 9v3.75m3-6v6"
                      />
                    </svg>
                  </span>
                <span>
                  <span className="block font-semibold text-gray-900">
                    {string("Eco Workflow")}
                  </span>
                  <span className="block text-sm text-gray-500">
                    {string("Build visual workflows for economy analysis")}
                  </span>
                </span>
                // Chevron right icon
                <svg
                  className="w-5 h-5 text-gray-400 group-hover:text-emerald-600 ml-auto transition-colors"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth="2">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M8.25 4.5l7.5 7.5-7.5 7.5"
                  />
                </svg>
              </span>
            </button>
          </div>
        // Footer
        <p className="mt-12 text-sm text-gray-400">
          {string("Built with ")}
          <a
            href="https://melange.re/"
            className="hover:text-blue-600 transition-colors"
            target="_blank"
            rel="noopener noreferrer">
            {string("Melange!")}
          </a>
          {string(" & ")}
          <a
            href="https://react.dev/"
            className="hover:text-blue-600 transition-colors"
            target="_blank"
            rel="noopener noreferrer">
            {string("React")}
          </a>
        </p>
      </div>
  </div>;
};
