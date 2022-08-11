import { DELETE_EVENT, FETCH_EVENT, FETCH_EVENT_BASIC } from "@/graphql/event";
import { IEvent } from "@/types/event.model";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed } from "vue";

export function useFetchEvent(uuid?: string) {
  const {
    result: fetchEventResult,
    loading,
    error,
    onError,
    onResult,
  } = useQuery<{ event: IEvent }>(
    FETCH_EVENT,
    {
      uuid,
    },
    () => ({
      enabled: uuid !== undefined,
    })
  );

  const event = computed(() => fetchEventResult.value?.event);

  return { event, loading, error, onError, onResult };
}

export function useFetchEventBasic(uuid: string) {
  const {
    result: fetchEventResult,
    loading,
    error,
    onResult,
    onError,
  } = useQuery<{ event: IEvent }>(FETCH_EVENT_BASIC, {
    uuid,
  });

  const event = computed(() => fetchEventResult.value?.event);

  return { event, loading, error, onResult, onError };
}

export function useDeleteEvent() {
  return useMutation<{ id: string }, { eventId: string }>(DELETE_EVENT, () => ({
    update(cache, { data }) {
      cache.evict({ id: `Event:${data?.id}` });
      cache.gc();
    },
  }));
}
