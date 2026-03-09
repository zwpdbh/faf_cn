// Tailwind CSS v3 Configuration
// See https://tailwindcss.com/docs/configuration for details

module.exports = {
  content: [
    './assets/js/**/*.js',
    './assets/css/**/*.css',
    './lib/faf_cn_web/**/*.*ex'
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('./assets/vendor/heroicons'),
    require('./assets/vendor/daisyui'),
  ],
}
