/**
 * Ensures data is correctly structured for the UI components
 */
export const ensureArray = (data) => {
  if (Array.isArray(data)) {
    return data;
  } else if (data && typeof data === 'object' && Array.isArray(data.data)) {
    return data.data;
  } else {
    console.warn("Data is not an array, returning empty array", data);
    return [];
  }
};

export const ensureObject = (data) => {
  if (!data) {
    return {};
  } else if (typeof data === 'object' && !Array.isArray(data)) {
    return data;
  } else {
    console.warn("Data is not an object, returning empty object", data);
    return {};
  }
};
