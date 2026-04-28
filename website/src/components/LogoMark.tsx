export function LogoMark({ className = "" }: { className?: string }) {
  return (
    <span
      className={[
        "relative grid h-9 w-9 place-items-center overflow-hidden rounded-lg border border-stroke bg-white",
        className,
      ].join(" ")}
      aria-hidden
    >
      <span className="relative grid h-5 w-5 place-items-center rounded-md bg-sageStrong text-white">
        <svg
          viewBox="0 0 24 24"
          className="h-3.5 w-3.5"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.4"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M8 12h8" />
          <path d="M12 8v8" />
          <path d="M16.5 8.5c1.4.9 2.3 2.1 2.7 3.5-.4 1.4-1.3 2.6-2.7 3.5" />
        </svg>
      </span>
    </span>
  );
}
