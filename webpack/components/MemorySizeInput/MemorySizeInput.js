import React, { useState } from 'react';
import RCInputNumber from 'rc-input-number';
import PropTypes from 'prop-types';
import { noop } from 'foremanReact/common/helpers';
import './MemorySizeInput.css';

const MemorySizeInput = ({ id, name, value, onChange }) => {
  const [inputValue, setInputValue] = useState();
  const [selectedUnit, setSelectedUnit] = useState('GB');

  const units = {
    TB: 2 ** 20,
    GB: 2 ** 10,
    MB: 2 ** 0,
  };

  if (value && !inputValue) {
    const match = Object.entries(units).find(
      ([, unitValue]) => value % unitValue === 0
    );

    if (match) {
      const [unit, unitValue] = match;
      setInputValue(value / unitValue);
      setSelectedUnit(unit);
    }
  }

  const handleInputChange = v => {
    setInputValue(v);
    onChange(v ? v * units[selectedUnit] : '');
  };

  const handleUnitChange = e => {
    setSelectedUnit(e.target.value);
    onChange(inputValue ? inputValue * units[e.target.value] : '');
  };

  return (
    <div className="input-group">
      <RCInputNumber
        id={id}
        value={inputValue}
        min={1}
        precision={0}
        onChange={handleInputChange}
        prefixCls="foreman-numeric-input"
      />
      <span className="input-group-btn">
        <select
          value={selectedUnit}
          onChange={handleUnitChange}
          className="form-control btn btn-default without_select2 selected-unit"
        >
          <option value="MB">MB</option>
          <option value="GB">GB</option>
          <option value="TB">TB</option>
        </select>
      </span>
      <input
        type="hidden"
        name={name}
        value={inputValue ? inputValue * units[selectedUnit] : ''}
      />
    </div>
  );
};

MemorySizeInput.propTypes = {
  id: PropTypes.string,
  name: PropTypes.string,
  value: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  onChange: PropTypes.func,
};

MemorySizeInput.defaultProps = {
  id: '',
  name: '',
  value: '',
  onChange: noop,
};

export default MemorySizeInput;
