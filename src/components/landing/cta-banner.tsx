import Link from "next/link";

export function CtaBanner() {
  return (
    <section className="max-w-6xl mx-auto px-6 mt-8 mb-16">
      <div
  className="relative rounded-2xl p-8 min-h-[480px] flex items-end overflow-hidden bg-[#e8e4da] bg-[length:100%_100%] bg-center"
  style={{ backgroundImage: "url('/landing/register-bg.jpg')" }}
>
  <div className="absolute inset-0 bg-black/30" />

  <Link
    href="/register"
    className="relative z-10 flex flex-col items-center bg-[#4a5c3a] text-white rounded-full px-6 py-3 font-semibold hover:bg-[#566b44] transition-colors"
  >
    <span>Register Now</span>
    <span className="text-[9px] text-white/50 font-normal mt-0.5">今すぐ登録</span>
  </Link>
</div>
    </section>
  );
}