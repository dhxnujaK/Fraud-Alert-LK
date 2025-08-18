import { render, screen } from '@testing-library/react';
import App from './App';

test('renders form elements', () => {
  render(<App />);
  expect(screen.getByText(/Job Post URL/i)).toBeInTheDocument();
  expect(screen.getByText(/Or Upload Image/i)).toBeInTheDocument();
});
