/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        background: '#0B1220',
        sidebar: '#111827',
        card: '#172033',
        cardBorder: '#1E293B',
        primary: {
          DEFAULT: '#6366F1',
          hover: '#4F46E5',
          light: '#818CF8'
        },
        success: '#22C55E',
        warning: '#F59E0B',
        danger: '#EF4444',
        textMain: '#F8FAFC',
        textMuted: '#94A3B8'
      }
    },
  },
  plugins: [],
}
