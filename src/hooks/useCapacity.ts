import { useState, useEffect } from 'react';
import { fakeCapacityData } from '../lib/fakeData';
import type { DailyCapacity } from '../types';

export function useCapacity() {
  const [capacityData, setCapacityData] = useState<DailyCapacity[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // For demo: Use fake data
    setCapacityData(fakeCapacityData);
    setLoading(false);
    
    // For real Supabase integration (uncomment when ready):
    // const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!);
    // const fetchCapacity = async () => {
    //   const { data } = await supabase.from('daily_capacity').select('*');
    //   setCapacityData(data || []);
    //   setLoading(false);
    // };
    // fetchCapacity();
  }, []);

  const getCapacityForDate = (date: string): DailyCapacity | undefined => {
    return capacityData.find(cap => cap.date === date);
  };

  const updateCapacity = (date: string, updates: Partial<DailyCapacity>) => {
    setCapacityData(capacityData.map(cap => 
      cap.date === date ? { ...cap, ...updates } : cap
    ));
    
    // For real Supabase integration:
    // supabase.from('daily_capacity').update(updates).eq('date', date);
  };

  const getWeeklyStats = () => {
    const totalCapacity = capacityData.reduce((sum, day) => sum + day.max_appointments, 0);
    const totalScheduled = capacityData.reduce((sum, day) => sum + day.current_scheduled, 0);
    const totalPredictedSpontaneous = capacityData.reduce((sum, day) => sum + day.predicted_spontaneous, 0);
    const totalMaxSpontaneous = capacityData.reduce((sum, day) => sum + day.max_spontaneous, 0);
    
    return {
      totalCapacity,
      totalScheduled,
      totalPredictedSpontaneous,
      totalMaxSpontaneous,
      availableSlots: totalCapacity - totalScheduled,
      capacityUtilization: Math.round((totalScheduled / totalCapacity) * 100)
    };
  };

  return { 
    capacityData, 
    getCapacityForDate, 
    updateCapacity, 
    getWeeklyStats,
    loading 
  };
}