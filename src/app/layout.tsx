import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'HubInfecto - Agenda de Pacientes',
  description: 'Sistema de gestión de citas médicas con vistas semanal y mensual',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}