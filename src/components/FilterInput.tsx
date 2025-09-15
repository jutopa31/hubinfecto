interface FilterInputProps {
  label: string;
  value: string;
  onChange: (value: string) => void;
}

export default function FilterInput({ label, value, onChange }: FilterInputProps) {
  return (
    <div className="flex flex-col">
      <label className="text-sm font-medium text-gray-700 mb-1">
        {label}
      </label>
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={`Buscar por ${label.toLowerCase()}...`}
        className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-900 bg-white"
      />
    </div>
  );
}