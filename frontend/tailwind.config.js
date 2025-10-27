// Version: 2.0.0
// Tailwind CSS Configuration

export default {
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx}'
  ],
  theme: {
    extend: {
      colors: {
        primary: '#00AFB9',
        'primary-hover': '#009ba3',
        'primary-light': '#f0fafb',
        'leave-annual': '#00AFB9',
        'leave-sick': '#FF6B6B',
        'leave-personal': '#FFD166',
        'leave-study': '#06D6A0',
        'status-pending': '#FFA500',
        'status-approved': '#10B981',
        'status-rejected': '#EF4444',
        'status-cancelled': '#9CA3AF'
      },
      maxWidth: {
        'mobile': '500px'
      }
    }
  },
  plugins: []
}

