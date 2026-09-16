"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef } from "react";

export function Hero() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const wrapperRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const video = videoRef.current;
    if (video) {
      video.muted = true;
      video.play().catch((err) => {
        console.error("Video autoplay was blocked:", err);
      });
    }
  }, []);

  useEffect(() => {
    let ticking = false;

    const handleScroll = () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          const scrollY = window.scrollY;
          if (wrapperRef.current) {
            // Video moves slower than scroll (0.4x speed) for parallax depth
            wrapperRef.current.style.transform = `translateY(${scrollY * 0.4}px)`;
          }
          ticking = false;
        });
        ticking = true;
      }
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <section className="relative overflow-hidden min-h-screen flex flex-col justify-end px-6 pb-16">
      {/* Parallax wrapper - taller than viewport so edges never show while translating */}
      <div ref={wrapperRef} className="absolute inset-0 -top-20 -bottom-20 z-0 will-change-transform">
        <video
          ref={videoRef}
          autoPlay
          loop
          muted
          playsInline
          preload="auto"
          className="w-full h-full object-cover"
        >
          <source src="/landing/hero-video.mp4" type="video/mp4" />
        </video>
      </div>

      <div className="absolute inset-0 bg-black/60 z-10" />

     <span
  className="hidden md:block absolute left-4 top-24 text-white/30 text-xs tracking-[0.3em] font-medium z-20 font-oswald"
  style={{ writingMode: "vertical-rl" }}
>
        ファウンダーズ・クラブ
      </span>

      <span
        className="hidden md:block absolute right-4 top-32 text-white/30 text-xs tracking-[0.3em] font-medium z-20"
        style={{ writingMode: "vertical-rl" }}
      >
        情熱を持って闘え
      </span>

      <div className="absolute top-25 left-30 z-20">
        <div className="inline-flex flex-col items-center bg-[#4a5c3a]/50 text-white rounded-full px-8 py-1.5 backdrop-blur-sm">
          <span className="flex items-center gap-1.5 text-xs font-medium">
            Ask AI <span aria-hidden></span>
          </span>
          <span className="text-[9px] text-white/50 mt-0.5">AIに質問</span>
        </div>
      </div>

      <div className="hidden md:block absolute bottom-4 right-1 z-15 w-[520px] h-[480px]">
        <Image src="/landing/corner-image.png" alt="" fill className="object-contain" />
      </div>

      <div className="max-w-7xl mx-auto relative z-20 w-full">
        <h1 className="text-20xl md:text-8xl font-bold tracking-tight text-white max-w-xl">
          IdeaSpark 3.0
        </h1>
        <p className="text-xs text-white/40 mt-1 tracking-wide">アイデアスパーク 3.0</p>

        <div className="flex flex-wrap gap-3 mt-6">
          <Link
            href="/register"
            className="flex flex-col items-center bg-[#4a5c3a] text-white rounded-full px-6 py-2.5 font-medium hover:bg-[#566b44] transition-colors"
          >
            <span>Register</span>
            <span className="text-[9px] text-white/50 font-normal mt-0.5">登録</span>
          </Link>
          <Link
            href="/event-details"
            className="flex flex-col items-center border border-white/30 text-white rounded-full px-6 py-2.5 font-medium hover:bg-white/10 transition-colors"
          >
            <span>Playbook</span>
            <span className="text-[9px] text-white/50 font-normal mt-0.5">プレイブック</span>
          </Link>
        </div>
      </div>
    </section>
  );
}