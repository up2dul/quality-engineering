import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { Provider } from 'jotai';
import LoginPage from '@/pages/auth/LoginPage';
import { clearToken } from '@/stores/authAtom';

function renderLoginPage() {
  return render(
    <Provider>
      <BrowserRouter>
        <LoginPage />
      </BrowserRouter>
    </Provider>
  );
}

describe('LoginPage', () => {
  beforeEach(() => {
    clearToken();
    vi.clearAllMocks();
  });

  it('renders login form', () => {
    renderLoginPage();

    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
  });

  it('prevents submission for empty email via HTML5 validation', async () => {
    renderLoginPage();

    const emailInput = screen.getByLabelText(/email/i) as HTMLInputElement;
    const submitButton = screen.getByRole('button', { name: /sign in/i });

    fireEvent.click(submitButton);

    await waitFor(() => {
      expect(emailInput.validity.valueMissing).toBe(true);
    });
  });

  it('prevents submission for invalid email format via HTML5 validation', async () => {
    renderLoginPage();

    const emailInput = screen.getByLabelText(/email/i) as HTMLInputElement;

    fireEvent.change(emailInput, {
      target: { value: 'not-an-email' },
    });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => {
      expect(emailInput.validity.typeMismatch).toBe(true);
    });
  });
});
