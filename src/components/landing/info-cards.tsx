"use client";

import { useState } from "react";

const days = [
  {
    label: "Day 1",
    labelJp: "1日目",
    description: "Pitch your idea and fun game",
    descriptionJp: "アイデアを発表して楽しいゲームをしよう",
  },
  {
    label: "Day 2",
    labelJp: "2日目",
    description: "Build your prototype and present",
    descriptionJp: "プロトタイプを作って発表しよう",
  },
];

export function InfoCards() {
  const [activeDay, setActiveDay] = useState(0);
  const current = days[activeDay];

  return (
    <section className="max-w-6xl mx-auto px-5 mt-15 mb-16">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:h-[560px]">
        {/* Left column: two stacked cards */}
        <div className="flex flex-col gap-4 h-full">
          <div
            className="relative rounded-2xl overflow-hidden flex-1 bg-cover bg-center"
            style={{ backgroundImage: "url('/landing/dates-bg.jpg')" }}
          >
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/10 to-transparent" />
            <div className="absolute bottom-4 left-4">
              <p className="text-white font-bold text-xl">5th &amp; 6th October</p>
              <p className="text-white/50 text-xs mt-0.5">10月5日・6日</p>
            </div>
          </div>

          <div className="relative rounded-2xl overflow-hidden flex-1 bg-[#0d1512] flex items-end">
            <div className="p-4">
              <p className="text-white font-bold text-lg">
                Resolve. Light the fire. Guide.
              </p>
              <p className="text-white/40 text-xs mt-0.5">
                決意し、火をつけ、導く。
              </p>
            </div>
          </div>
        </div>

        {/* Right column: tall day card, brown themed, single static image */}
        <div
          className="relative rounded-2xl overflow-hidden h-full bg-[#2b1710] bg-cover bg-left"
          style={{ backgroundImage: "url('/landing/day-bg.jpg')" }}
        >
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/10 to-transparent" />

          <div className="absolute bottom-105 left-4 right-4">
            <p className="text-white font-bold text-xl">{current.label}</p>
            <p className="text-white/50 text-xs mt-0.5">{current.labelJp}</p>
            <p className="text-white/80 text-sm mt-2">{current.description}</p>
            <p className="text-white/40 text-xs mt-0.5">{current.descriptionJp}</p>

            <div className="flex gap-1.5 mt-3">
              {days.map((day, index) => (
                <button
                  key={day.label}
                  type="button"
                  onClick={() => setActiveDay(index)}
                  aria-label={`Show ${day.label}`}
                  className={`w-1.5 h-1.5 rounded-full transition-colors ${
                    index === activeDay ? "bg-green-400" : "bg-white/40"
                  }`}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}