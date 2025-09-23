export const formatAddress = (
  address: string,
  prefixLength: number = 2,
  suffixLength: number = 4
) => {
  if (!address) return "";
  return `${address.slice(0, prefixLength)}...${address.slice(-suffixLength)}`;
};
